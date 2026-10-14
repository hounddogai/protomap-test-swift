import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves primary statement records through their life cycle and keeps a journal of what it did.
    final class PrimaryStatementRecordManager {
        var store: any PrimaryStatementRecordStore
        var validator: PrimaryStatementRecordValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any PrimaryStatementRecordStore, validator: PrimaryStatementRecordValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("primary statement record \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PrimaryStatementRecordStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary statement record \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PrimaryStatementRecordStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func sweep(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
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

    static func newPrimaryStatementRecordManager(_ store: any PrimaryStatementRecordStore, clock: any Kit.Clocks.Clock) -> PrimaryStatementRecordManager {
        return PrimaryStatementRecordManager(
            store: store,
            validator: defaultPrimaryStatementRecordValidator(),
            clock: clock,
            journal: []
        )
    }
}
