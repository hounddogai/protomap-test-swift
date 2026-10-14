import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves adaptive alert requests through their life cycle and keeps a journal of what it did.
    final class AdaptiveAlertRequestManager {
        var store: any AdaptiveAlertRequestStore
        var validator: AdaptiveAlertRequestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: AdaptiveAlertRequestEngine

        init(store: any AdaptiveAlertRequestStore, validator: AdaptiveAlertRequestValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: AdaptiveAlertRequestEngine) {
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
                throw Kit.Failure("adaptive alert request \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AdaptiveAlertRequestStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("adaptive alert request \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AdaptiveAlertRequestStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("adaptive alert request \(code) not found")
            }
            let result = engine.price(item)
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

    static func newAdaptiveAlertRequestManager(_ store: any AdaptiveAlertRequestStore, clock: any Kit.Clocks.Clock) -> AdaptiveAlertRequestManager {
        return AdaptiveAlertRequestManager(
            store: store,
            validator: defaultAdaptiveAlertRequestValidator(),
            clock: clock,
            journal: [],
            engine: defaultAdaptiveAlertRequestEngine()
        )
    }
}
