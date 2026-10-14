import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves legacy recall templates through their life cycle and keeps a journal of what it did.
    final class LegacyRecallTemplateService {
        var store: any LegacyRecallTemplateStore
        var validator: LegacyRecallTemplateValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: LegacyRecallTemplateEngine

        init(store: any LegacyRecallTemplateStore, validator: LegacyRecallTemplateValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: LegacyRecallTemplateEngine) {
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
                throw Kit.Failure("legacy recall template \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LegacyRecallTemplateStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy recall template \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LegacyRecallTemplateStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy recall template \(code) not found")
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

    static func newLegacyRecallTemplateService(_ store: any LegacyRecallTemplateStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> LegacyRecallTemplateService {
        return LegacyRecallTemplateService(
            store: store,
            validator: defaultLegacyRecallTemplateValidator(),
            clock: clock,
            journal: [],
            engine: defaultLegacyRecallTemplateEngine(flags)
        )
    }
}
