import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves tiered remittance requests through their life cycle and keeps a journal of what it did.
    final class TieredRemittanceRequestWorkflow {
        var store: any TieredRemittanceRequestStore
        var validator: TieredRemittanceRequestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: TieredRemittanceRequestEngine

        init(store: any TieredRemittanceRequestStore, validator: TieredRemittanceRequestValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: TieredRemittanceRequestEngine) {
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
                throw Kit.Failure("tiered remittance request \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(TieredRemittanceRequestStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered remittance request \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(TieredRemittanceRequestStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered remittance request \(code) not found")
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

    static func newTieredRemittanceRequestWorkflow(_ store: any TieredRemittanceRequestStore, clock: any Kit.Clocks.Clock) -> TieredRemittanceRequestWorkflow {
        return TieredRemittanceRequestWorkflow(
            store: store,
            validator: defaultTieredRemittanceRequestValidator(),
            clock: clock,
            journal: [],
            engine: defaultTieredRemittanceRequestEngine()
        )
    }
}
