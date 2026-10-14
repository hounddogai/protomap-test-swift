import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves alert mappings through their life cycle and keeps a journal of what it did.
    final class AlertMappingService {
        var store: any AlertMappingStore
        var validator: AlertMappingValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: AlertMappingEngine

        init(store: any AlertMappingStore, validator: AlertMappingValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: AlertMappingEngine) {
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
                throw Kit.Failure("alert mapping \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AlertMappingStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("alert mapping \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AlertMappingStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("alert mapping \(code) not found")
            }
            let result = engine.compute(item)
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

    static func newAlertMappingService(_ store: any AlertMappingStore, clock: any Kit.Clocks.Clock) -> AlertMappingService {
        return AlertMappingService(
            store: store,
            validator: defaultAlertMappingValidator(),
            clock: clock,
            journal: [],
            engine: defaultAlertMappingEngine()
        )
    }
}
