import AcmePlatform
import Foundation

extension Referrals {
    /// Moves regional slot digests through their life cycle and keeps a journal of what it did.
    final class RegionalSlotDigestManager {
        var store: any RegionalSlotDigestStore
        var validator: RegionalSlotDigestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any RegionalSlotDigestStore, validator: RegionalSlotDigestValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional slot digest \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RegionalSlotDigestStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional slot digest \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RegionalSlotDigestStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func reviewStale(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.createdAt > cutoff {
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

    static func newRegionalSlotDigestManager(_ store: any RegionalSlotDigestStore, clock: any Kit.Clocks.Clock) -> RegionalSlotDigestManager {
        return RegionalSlotDigestManager(
            store: store,
            validator: defaultRegionalSlotDigestValidator(),
            clock: clock,
            journal: []
        )
    }
}
