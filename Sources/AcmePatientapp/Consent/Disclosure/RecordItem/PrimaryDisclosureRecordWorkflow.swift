import AcmePlatform
import Foundation

extension Consent {
    /// Moves primary disclosure records through their life cycle and keeps a journal of what it did.
    final class PrimaryDisclosureRecordManager {
        var store: any PrimaryDisclosureRecordStore
        var validator: PrimaryDisclosureRecordValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any PrimaryDisclosureRecordStore, validator: PrimaryDisclosureRecordValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary disclosure record \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PrimaryDisclosureRecordStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary disclosure record \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PrimaryDisclosureRecordStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
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

    static func newPrimaryDisclosureRecordManager(_ store: any PrimaryDisclosureRecordStore, clock: any Kit.Clocks.Clock) -> PrimaryDisclosureRecordManager {
        return PrimaryDisclosureRecordManager(
            store: store,
            validator: defaultPrimaryDisclosureRecordValidator(),
            clock: clock,
            journal: []
        )
    }
}
