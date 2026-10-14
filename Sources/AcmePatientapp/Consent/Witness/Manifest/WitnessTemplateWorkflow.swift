import AcmePlatform
import Foundation

extension Consent {
    /// Moves witness templates through their life cycle and keeps a journal of what it did.
    final class WitnessTemplateWorkflow {
        var store: any WitnessTemplateStore
        var validator: WitnessTemplateValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: WitnessTemplateEngine

        init(store: any WitnessTemplateStore, validator: WitnessTemplateValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: WitnessTemplateEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("witness template \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(WitnessTemplateStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("witness template \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(WitnessTemplateStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("witness template \(code) not found")
            }
            let result = engine.compute(item)
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

    static func newWitnessTemplateWorkflow(_ store: any WitnessTemplateStore, clock: any Kit.Clocks.Clock) -> WitnessTemplateWorkflow {
        return WitnessTemplateWorkflow(
            store: store,
            validator: defaultWitnessTemplateValidator(),
            clock: clock,
            journal: [],
            engine: defaultWitnessTemplateEngine()
        )
    }
}
