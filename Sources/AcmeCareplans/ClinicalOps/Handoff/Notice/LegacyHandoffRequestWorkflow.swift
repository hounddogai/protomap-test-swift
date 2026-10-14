import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves legacy handoff requests through their life cycle and keeps a journal of what it did.
    final class LegacyHandoffRequestManager {
        var store: any LegacyHandoffRequestStore
        var validator: LegacyHandoffRequestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any LegacyHandoffRequestStore, validator: LegacyHandoffRequestValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy handoff request \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LegacyHandoffRequestStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy handoff request \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LegacyHandoffRequestStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func reviewStale(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.startsAt > cutoff {
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

    static func newLegacyHandoffRequestManager(_ store: any LegacyHandoffRequestStore, clock: any Kit.Clocks.Clock) -> LegacyHandoffRequestManager {
        return LegacyHandoffRequestManager(
            store: store,
            validator: defaultLegacyHandoffRequestValidator(),
            clock: clock,
            journal: []
        )
    }
}
