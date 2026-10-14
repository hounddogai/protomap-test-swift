import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves alert slots through their life cycle and keeps a journal of what it did.
    final class AlertSlotService {
        var store: any AlertSlotStore
        var validator: AlertSlotValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: AlertSlotEngine

        init(store: any AlertSlotStore, validator: AlertSlotValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: AlertSlotEngine) {
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
                throw Kit.Failure("alert slot \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AlertSlotStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("alert slot \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AlertSlotStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("alert slot \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.startsAt > cutoff {
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

    static func newAlertSlotService(_ store: any AlertSlotStore, clock: any Kit.Clocks.Clock) -> AlertSlotService {
        return AlertSlotService(
            store: store,
            validator: defaultAlertSlotValidator(),
            clock: clock,
            journal: [],
            engine: defaultAlertSlotEngine()
        )
    }
}
