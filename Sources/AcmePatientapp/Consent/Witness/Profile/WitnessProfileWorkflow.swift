import AcmePlatform
import Foundation

extension Consent {
    /// Moves witness profiles through their life cycle and keeps a journal of what it did.
    final class WitnessProfileWorkflow {
        var store: any WitnessProfileStore
        var validator: WitnessProfileValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: WitnessProfileEngine

        init(store: any WitnessProfileStore, validator: WitnessProfileValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: WitnessProfileEngine) {
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
                throw Kit.Failure("witness profile \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(WitnessProfileStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("witness profile \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(WitnessProfileStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("witness profile \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.createdAt > cutoff {
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

    static func newWitnessProfileWorkflow(_ store: any WitnessProfileStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> WitnessProfileWorkflow {
        return WitnessProfileWorkflow(
            store: store,
            validator: defaultWitnessProfileValidator(),
            clock: clock,
            journal: [],
            engine: defaultWitnessProfileEngine(flags)
        )
    }
}
