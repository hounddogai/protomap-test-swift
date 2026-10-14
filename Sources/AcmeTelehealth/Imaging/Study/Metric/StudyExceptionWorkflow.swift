import AcmePlatform
import Foundation

extension Imaging {
    /// Moves study exceptions through their life cycle and keeps a journal of what it did.
    final class StudyExceptionManager {
        var store: any StudyExceptionStore
        var validator: StudyExceptionValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: StudyExceptionEngine

        init(store: any StudyExceptionStore, validator: StudyExceptionValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: StudyExceptionEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("study exception \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(StudyExceptionStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("study exception \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(StudyExceptionStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("study exception \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newStudyExceptionManager(_ store: any StudyExceptionStore, clock: any Kit.Clocks.Clock) -> StudyExceptionManager {
        return StudyExceptionManager(
            store: store,
            validator: defaultStudyExceptionValidator(),
            clock: clock,
            journal: [],
            engine: defaultStudyExceptionEngine()
        )
    }
}
