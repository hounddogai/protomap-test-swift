import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves formulary records through their life cycle and keeps a journal of what it did.
    final class FormularyRecordManager {
        var store: any FormularyRecordStore
        var validator: FormularyRecordValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: FormularyRecordEngine

        init(store: any FormularyRecordStore, validator: FormularyRecordValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: FormularyRecordEngine) {
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
                throw Kit.Failure("formulary record \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FormularyRecordStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("formulary record \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FormularyRecordStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("formulary record \(code) not found")
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

    static func newFormularyRecordManager(_ store: any FormularyRecordStore, clock: any Kit.Clocks.Clock) -> FormularyRecordManager {
        return FormularyRecordManager(
            store: store,
            validator: defaultFormularyRecordValidator(),
            clock: clock,
            journal: [],
            engine: defaultFormularyRecordEngine()
        )
    }
}
