import AcmePlatform
import Foundation

extension Consent {
    /// Moves language estimates through their life cycle and keeps a journal of what it did.
    final class LanguageEstimateDesk {
        var store: any LanguageEstimateStore
        var validator: LanguageEstimateValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: LanguageEstimateEngine

        init(store: any LanguageEstimateStore, validator: LanguageEstimateValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: LanguageEstimateEngine) {
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
                throw Kit.Failure("language estimate \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LanguageEstimateStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("language estimate \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LanguageEstimateStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("language estimate \(code) not found")
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

    static func newLanguageEstimateDesk(_ store: any LanguageEstimateStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> LanguageEstimateDesk {
        return LanguageEstimateDesk(
            store: store,
            validator: defaultLanguageEstimateValidator(),
            clock: clock,
            journal: [],
            engine: defaultLanguageEstimateEngine(flags)
        )
    }
}
