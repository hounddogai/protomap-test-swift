import AcmePlatform
import Foundation

extension Imaging {
    /// Moves tiered care protocol allocations through their life cycle and keeps a journal of what it did.
    final class TieredCareProtocolAllocationManager {
        var store: any TieredCareProtocolAllocationStore
        var validator: TieredCareProtocolAllocationValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any TieredCareProtocolAllocationStore, validator: TieredCareProtocolAllocationValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered care protocol allocation \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(TieredCareProtocolAllocationStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered care protocol allocation \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(TieredCareProtocolAllocationStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func scan(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.endsAt > cutoff {
                    continue
                }
                let problems = validator.validate(item)
                if problems.count == 0 {
                    continue
                }
                self.note("\(item.code) needs attention: \(problems.joined(separator: ", "))")
                changed += 1
            }
            return changed
        }
    }

    static func newTieredCareProtocolAllocationManager(_ store: any TieredCareProtocolAllocationStore, clock: any Kit.Clocks.Clock) -> TieredCareProtocolAllocationManager {
        return TieredCareProtocolAllocationManager(
            store: store,
            validator: defaultTieredCareProtocolAllocationValidator(),
            clock: clock,
            journal: []
        )
    }
}
