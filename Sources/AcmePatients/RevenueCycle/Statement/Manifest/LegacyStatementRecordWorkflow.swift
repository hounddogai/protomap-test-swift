import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves legacy statement records through their life cycle and keeps a journal of what it did.
    final class LegacyStatementRecordDesk {
        var store: any LegacyStatementRecordStore
        var validator: LegacyStatementRecordValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any LegacyStatementRecordStore, validator: LegacyStatementRecordValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("legacy statement record \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LegacyStatementRecordStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy statement record \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LegacyStatementRecordStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func reviewStale(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.updatedAt > cutoff {
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

    static func newLegacyStatementRecordDesk(_ store: any LegacyStatementRecordStore, clock: any Kit.Clocks.Clock) -> LegacyStatementRecordDesk {
        return LegacyStatementRecordDesk(
            store: store,
            validator: defaultLegacyStatementRecordValidator(),
            clock: clock,
            journal: []
        )
    }
}
