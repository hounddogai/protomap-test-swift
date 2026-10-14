import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves substitution quotas through their life cycle and keeps a journal of what it did.
    final class SubstitutionQuotaManager {
        var store: any SubstitutionQuotaStore
        var validator: SubstitutionQuotaValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: SubstitutionQuotaEngine

        init(store: any SubstitutionQuotaStore, validator: SubstitutionQuotaValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: SubstitutionQuotaEngine) {
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
                throw Kit.Failure("substitution quota \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SubstitutionQuotaStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("substitution quota \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SubstitutionQuotaStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("substitution quota \(code) not found")
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

    static func newSubstitutionQuotaManager(_ store: any SubstitutionQuotaStore, clock: any Kit.Clocks.Clock) -> SubstitutionQuotaManager {
        return SubstitutionQuotaManager(
            store: store,
            validator: defaultSubstitutionQuotaValidator(),
            clock: clock,
            journal: [],
            engine: defaultSubstitutionQuotaEngine()
        )
    }
}
