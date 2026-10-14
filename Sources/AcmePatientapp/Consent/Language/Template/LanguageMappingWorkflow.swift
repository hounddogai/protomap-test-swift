import AcmePlatform
import Foundation

extension Consent {
    /// Moves language mappings through their life cycle and keeps a journal of what it did.
    final class LanguageMappingWorkflow {
        var store: any LanguageMappingStore
        var validator: LanguageMappingValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: LanguageMappingEngine

        init(store: any LanguageMappingStore, validator: LanguageMappingValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: LanguageMappingEngine) {
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
                throw Kit.Failure("language mapping \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LanguageMappingStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("language mapping \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LanguageMappingStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("language mapping \(code) not found")
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

    static func newLanguageMappingWorkflow(_ store: any LanguageMappingStore, clock: any Kit.Clocks.Clock) -> LanguageMappingWorkflow {
        return LanguageMappingWorkflow(
            store: store,
            validator: defaultLanguageMappingValidator(),
            clock: clock,
            journal: [],
            engine: defaultLanguageMappingEngine()
        )
    }
}
