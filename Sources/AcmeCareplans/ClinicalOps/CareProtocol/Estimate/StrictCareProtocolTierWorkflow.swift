import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves strict care protocol tiers through their life cycle and keeps a journal of what it did.
    final class StrictCareProtocolTierWorkflow {
        var store: any StrictCareProtocolTierStore
        var validator: StrictCareProtocolTierValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: StrictCareProtocolTierEngine

        init(store: any StrictCareProtocolTierStore, validator: StrictCareProtocolTierValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: StrictCareProtocolTierEngine) {
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
                throw Kit.Failure("strict care protocol tier \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(StrictCareProtocolTierStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict care protocol tier \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(StrictCareProtocolTierStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict care protocol tier \(code) not found")
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
                if item.expiresAt > cutoff {
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

    static func newStrictCareProtocolTierWorkflow(_ store: any StrictCareProtocolTierStore, clock: any Kit.Clocks.Clock) -> StrictCareProtocolTierWorkflow {
        return StrictCareProtocolTierWorkflow(
            store: store,
            validator: defaultStrictCareProtocolTierValidator(),
            clock: clock,
            journal: [],
            engine: defaultStrictCareProtocolTierEngine()
        )
    }
}
