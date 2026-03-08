struct GS1Element {
    let ai: String
    let value: String
}

struct GS1ApplicationIdentifier {
    let ai: String
    let fixedLength: Int?
    let maxLength: Int
}

enum GS1Parser {
    static let FNC1 = "\u{1D}"

    private static let registry: [String: GS1ApplicationIdentifier] = [
        "01": GS1ApplicationIdentifier(ai: "01", fixedLength: 14, maxLength: 14), // GTIN
        "11": GS1ApplicationIdentifier(ai: "11", fixedLength: 6, maxLength: 6), // Manufactur date
        "17": GS1ApplicationIdentifier(ai: "17", fixedLength: 6, maxLength: 6), // Expiry YYMMDD
        "21": GS1ApplicationIdentifier(ai: "21", fixedLength: nil, maxLength: 20) // Serial
    ]

    static func parse(_ input: String) -> [GS1Element] {
        var index = input.startIndex
        var results: [GS1Element] = []

        while index < input.endIndex {
            let ai = String(input[index ..< input.index(index, offsetBy: 2)])
            index = input.index(index, offsetBy: 2)

            guard let aiInfo = registry[ai] else {
                break
            }

            if let fixed = aiInfo.fixedLength {
                let end = input.index(index, offsetBy: fixed)
                let value = String(input[index ..< end])

                results.append(GS1Element(ai: ai, value: value))

                index = end
            } else {
                var end = index

                while end < input.endIndex, input[end] != Character(FNC1) {
                    end = input.index(after: end)
                }

                let value = String(input[index ..< end])
                results.append(GS1Element(ai: ai, value: value))
                index = end < input.endIndex ? input.index(after: end) : end
            }
        }

        return results
    }
}
