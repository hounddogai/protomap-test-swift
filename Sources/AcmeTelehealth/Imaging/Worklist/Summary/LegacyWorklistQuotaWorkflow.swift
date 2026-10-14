import AcmePlatform
import Foundation

extension Imaging {
    /// Moves legacy worklist quotas through their life cycle and keeps a journal of what it did.
    final class LegacyWorklistQuotaService {
        var store: any LegacyWorklistQuotaStore
        var validator: LegacyWorklistQuotaValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: LegacyWorklistQuotaEngine

        init(store: any LegacyWorklistQuotaStore, validator: LegacyWorklistQuotaValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: LegacyWorklistQuotaEngine) {
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
                throw Kit.Failure("legacy worklist quota \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LegacyWorklistQuotaStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy worklist quota \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LegacyWorklistQuotaStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy worklist quota \(code) not found")
            }
            let result = engine.evaluate(item)
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

    static func newLegacyWorklistQuotaService(_ store: any LegacyWorklistQuotaStore, clock: any Kit.Clocks.Clock) -> LegacyWorklistQuotaService {
        return LegacyWorklistQuotaService(
            store: store,
            validator: defaultLegacyWorklistQuotaValidator(),
            clock: clock,
            journal: [],
            engine: defaultLegacyWorklistQuotaEngine()
        )
    }
}
