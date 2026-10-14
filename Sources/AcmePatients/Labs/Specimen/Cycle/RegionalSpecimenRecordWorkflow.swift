import AcmePlatform
import Foundation

extension Labs {
    /// Moves regional specimen records through their life cycle and keeps a journal of what it did.
    final class RegionalSpecimenRecordCoordinator {
        var store: any RegionalSpecimenRecordStore
        var validator: RegionalSpecimenRecordValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any RegionalSpecimenRecordStore, validator: RegionalSpecimenRecordValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("regional specimen record \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RegionalSpecimenRecordStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional specimen record \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RegionalSpecimenRecordStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
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

    static func newRegionalSpecimenRecordCoordinator(_ store: any RegionalSpecimenRecordStore, clock: any Kit.Clocks.Clock) -> RegionalSpecimenRecordCoordinator {
        return RegionalSpecimenRecordCoordinator(
            store: store,
            validator: defaultRegionalSpecimenRecordValidator(),
            clock: clock,
            journal: []
        )
    }
}
