import Foundation

final class AccuChekDispatchGroup {
    private let group = DispatchGroup()
    private let lock = NSLock()
    private var count = 0
    private var data: Data?

    func enter() {
        lock.lock()
        count += 1
        data = nil
        lock.unlock()
        group.enter()
    }

    func leave(_ data: Data) {
        lock.lock()
        self.data = data
        count -= 1
        lock.unlock()

        guard count >= 0 else {
            // Prevent crash on multiple leave calls
            return
        }

        group.leave()
    }

    @discardableResult func wait() -> Data? {
        group.wait()
        return data
    }

    @discardableResult func wait(timeout: DispatchTime) -> Data? {
        _ = group.wait(timeout: timeout)
        return data
    }
}
