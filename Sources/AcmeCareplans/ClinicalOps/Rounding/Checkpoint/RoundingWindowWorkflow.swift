import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves rounding windows through their life cycle and keeps a journal of what it did.
    final class RoundingWindowWorkflow {
        var store: any RoundingWindowStore
        var validator: RoundingWindowValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RoundingWindowEngine

        init(store: any RoundingWindowStore, validator: RoundingWindowValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RoundingWindowEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("rounding window \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RoundingWindowStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("rounding window \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RoundingWindowStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("rounding window \(code) not found")
            }
            let result = engine.evaluate(item)
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

    static func newRoundingWindowWorkflow(_ store: any RoundingWindowStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> RoundingWindowWorkflow {
        return RoundingWindowWorkflow(
            store: store,
            validator: defaultRoundingWindowValidator(),
            clock: clock,
            journal: [],
            engine: defaultRoundingWindowEngine(flags)
        )
    }
}
