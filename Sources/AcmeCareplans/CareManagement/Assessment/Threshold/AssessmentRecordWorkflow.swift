import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves assessment records through their life cycle and keeps a journal of what it did.
    final class AssessmentRecordManager {
        var store: any AssessmentRecordStore
        var validator: AssessmentRecordValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any AssessmentRecordStore, validator: AssessmentRecordValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("assessment record \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AssessmentRecordStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("assessment record \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AssessmentRecordStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func reviewStale(_ cutoff: Int) -> Int {
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

    static func newAssessmentRecordManager(_ store: any AssessmentRecordStore, clock: any Kit.Clocks.Clock) -> AssessmentRecordManager {
        return AssessmentRecordManager(
            store: store,
            validator: defaultAssessmentRecordValidator(),
            clock: clock,
            journal: []
        )
    }
}
