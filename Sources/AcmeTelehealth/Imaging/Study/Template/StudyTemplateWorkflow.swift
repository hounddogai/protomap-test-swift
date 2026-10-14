import AcmePlatform
import Foundation

extension Imaging {
    /// Moves study templates through their life cycle and keeps a journal of what it did.
    final class StudyTemplateManager {
        var store: any StudyTemplateStore
        var validator: StudyTemplateValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any StudyTemplateStore, validator: StudyTemplateValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("study template \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(StudyTemplateStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("study template \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(StudyTemplateStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
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

    static func newStudyTemplateManager(_ store: any StudyTemplateStore, clock: any Kit.Clocks.Clock) -> StudyTemplateManager {
        return StudyTemplateManager(
            store: store,
            validator: defaultStudyTemplateValidator(),
            clock: clock,
            journal: []
        )
    }
}
