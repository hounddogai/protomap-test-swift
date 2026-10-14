import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves fallback outreach audits through their life cycle and keeps a journal of what it did.
    final class FallbackOutreachAuditDesk {
        var store: any FallbackOutreachAuditStore
        var validator: FallbackOutreachAuditValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: FallbackOutreachAuditEngine

        init(store: any FallbackOutreachAuditStore, validator: FallbackOutreachAuditValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: FallbackOutreachAuditEngine) {
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
                throw Kit.Failure("fallback outreach audit \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FallbackOutreachAuditStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback outreach audit \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FallbackOutreachAuditStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback outreach audit \(code) not found")
            }
            let result = engine.compute(item)
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

    static func newFallbackOutreachAuditDesk(_ store: any FallbackOutreachAuditStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> FallbackOutreachAuditDesk {
        return FallbackOutreachAuditDesk(
            store: store,
            validator: defaultFallbackOutreachAuditValidator(),
            clock: clock,
            journal: [],
            engine: defaultFallbackOutreachAuditEngine(flags)
        )
    }
}
