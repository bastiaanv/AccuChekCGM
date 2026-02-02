import Foundation

extension AccuChekPeripheralManager {
    func segmentData(data: Data, mtu: Int = 20) -> [Data] {
        let chunkSize = mtu - 1
        guard chunkSize > 0 else {
            return []
        }

        // Split Data into chunks
        let chunks: [Data] = stride(from: 0, to: data.count, by: chunkSize).map { startIndex in
            let endIndex = min(startIndex + chunkSize, data.count)
            return Data(data.subdata(in: startIndex ..< endIndex))
        }

        let lastIndex = chunks.count - 1

        return chunks.enumerated().map { index, payloadChunk in
            let header = createSegmentationHeader(
                index,
                index == 0,
                index == lastIndex
            )

            var packet = Data(capacity: 1 + payloadChunk.count)
            packet.append(header) // segmentation header
            packet.append(payloadChunk) // payload

            return packet
        }
    }

    private func createSegmentationHeader(_ index: Int, _ isFirstSegment: Bool, _ islastSegment: Bool) -> UInt8 {
        var output = UInt8(index << 2)

        if isFirstSegment {
            output |= 1
        }

        if islastSegment {
            output |= 2
        }

        return output
    }
}
