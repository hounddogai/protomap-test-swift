import AcmePlatform
import Foundation

extension Consent {
    /// Moves language quotas through their life cycle and keeps a journal of what it did.
    final class LanguageQuotaDesk {
        var store: any LanguageQuotaStore
        var validator: LanguageQuotaValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: LanguageQuotaEngine

        init(store: any LanguageQuotaStore, validator: LanguageQuotaValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: LanguageQuotaEngine) {
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
                throw Kit.Failure("language quota \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LanguageQuotaStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("language quota \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LanguageQuotaStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("language quota \(code) not found")
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
                if item.endsAt > cutoff {
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

    static func newLanguageQuotaDesk(_ store: any LanguageQuotaStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> LanguageQuotaDesk {
        return LanguageQuotaDesk(
            store: store,
            validator: defaultLanguageQuotaValidator(),
            clock: clock,
            journal: [],
            engine: defaultLanguageQuotaEngine(flags)
        )
    }
}
