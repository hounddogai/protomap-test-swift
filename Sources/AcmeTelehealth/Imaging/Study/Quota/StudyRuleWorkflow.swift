import AcmePlatform
import Foundation

extension Imaging {
    /// Moves study rules through their life cycle and keeps a journal of what it did.
    final class StudyRuleCoordinator {
        var store: any StudyRuleStore
        var validator: StudyRuleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: StudyRuleEngine

        init(store: any StudyRuleStore, validator: StudyRuleValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: StudyRuleEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("study rule \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(StudyRuleStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("study rule \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(StudyRuleStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("study rule \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newStudyRuleCoordinator(_ store: any StudyRuleStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> StudyRuleCoordinator {
        return StudyRuleCoordinator(
            store: store,
            validator: defaultStudyRuleValidator(),
            clock: clock,
            journal: [],
            engine: defaultStudyRuleEngine(flags)
        )
    }
}
