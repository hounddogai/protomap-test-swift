import AcmePlatform
import Foundation

extension Labs {
    /// Moves capped courier profiles through their life cycle and keeps a journal of what it did.
    final class CappedCourierProfileWorkflow {
        var store: any CappedCourierProfileStore
        var validator: CappedCourierProfileValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CappedCourierProfileEngine

        init(store: any CappedCourierProfileStore, validator: CappedCourierProfileValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CappedCourierProfileEngine) {
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
                throw Kit.Failure("capped courier profile \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CappedCourierProfileStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped courier profile \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CappedCourierProfileStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped courier profile \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newCappedCourierProfileWorkflow(_ store: any CappedCourierProfileStore, clock: any Kit.Clocks.Clock) -> CappedCourierProfileWorkflow {
        return CappedCourierProfileWorkflow(
            store: store,
            validator: defaultCappedCourierProfileValidator(),
            clock: clock,
            journal: [],
            engine: defaultCappedCourierProfileEngine()
        )
    }
}
