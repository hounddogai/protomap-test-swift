import AcmePlatform
import Foundation

extension Staffing {
    /// Moves default float pool claims through their life cycle and keeps a journal of what it did.
    final class DefaultFloatPoolClaimWorkflow {
        var store: any DefaultFloatPoolClaimStore
        var validator: DefaultFloatPoolClaimValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: DefaultFloatPoolClaimEngine

        init(store: any DefaultFloatPoolClaimStore, validator: DefaultFloatPoolClaimValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: DefaultFloatPoolClaimEngine) {
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
                throw Kit.Failure("default float pool claim \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(DefaultFloatPoolClaimStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("default float pool claim \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(DefaultFloatPoolClaimStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("default float pool claim \(code) not found")
            }
            let result = engine.run(item)
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

    static func newDefaultFloatPoolClaimWorkflow(_ store: any DefaultFloatPoolClaimStore, clock: any Kit.Clocks.Clock) -> DefaultFloatPoolClaimWorkflow {
        return DefaultFloatPoolClaimWorkflow(
            store: store,
            validator: defaultDefaultFloatPoolClaimValidator(),
            clock: clock,
            journal: [],
            engine: defaultDefaultFloatPoolClaimEngine()
        )
    }
}
