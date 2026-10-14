import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves alert entries through their life cycle and keeps a journal of what it did.
    final class AlertEntryService {
        var store: any AlertEntryStore
        var validator: AlertEntryValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: AlertEntryEngine

        init(store: any AlertEntryStore, validator: AlertEntryValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: AlertEntryEngine) {
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
                throw Kit.Failure("alert entry \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AlertEntryStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("alert entry \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AlertEntryStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("alert entry \(code) not found")
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

    static func newAlertEntryService(_ store: any AlertEntryStore, clock: any Kit.Clocks.Clock) -> AlertEntryService {
        return AlertEntryService(
            store: store,
            validator: defaultAlertEntryValidator(),
            clock: clock,
            journal: [],
            engine: defaultAlertEntryEngine()
        )
    }
}
