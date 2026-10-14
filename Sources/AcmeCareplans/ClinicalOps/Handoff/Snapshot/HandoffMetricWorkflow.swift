import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves handoff metrics through their life cycle and keeps a journal of what it did.
    final class HandoffMetricCoordinator {
        var store: any HandoffMetricStore
        var validator: HandoffMetricValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: HandoffMetricEngine

        init(store: any HandoffMetricStore, validator: HandoffMetricValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: HandoffMetricEngine) {
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
                throw Kit.Failure("handoff metric \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(HandoffMetricStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("handoff metric \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(HandoffMetricStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("handoff metric \(code) not found")
            }
            let result = engine.price(item)
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

    static func newHandoffMetricCoordinator(_ store: any HandoffMetricStore, clock: any Kit.Clocks.Clock) -> HandoffMetricCoordinator {
        return HandoffMetricCoordinator(
            store: store,
            validator: defaultHandoffMetricValidator(),
            clock: clock,
            journal: [],
            engine: defaultHandoffMetricEngine()
        )
    }
}
