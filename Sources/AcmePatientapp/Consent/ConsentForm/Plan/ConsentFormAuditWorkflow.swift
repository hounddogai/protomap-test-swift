import AcmePlatform
import Foundation

extension Consent {
    /// Moves consent form audits through their life cycle and keeps a journal of what it did.
    final class ConsentFormAuditCoordinator {
        var store: any ConsentFormAuditStore
        var validator: ConsentFormAuditValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ConsentFormAuditEngine

        init(store: any ConsentFormAuditStore, validator: ConsentFormAuditValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ConsentFormAuditEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("consent form audit \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ConsentFormAuditStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("consent form audit \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ConsentFormAuditStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("consent form audit \(code) not found")
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

    static func newConsentFormAuditCoordinator(_ store: any ConsentFormAuditStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ConsentFormAuditCoordinator {
        return ConsentFormAuditCoordinator(
            store: store,
            validator: defaultConsentFormAuditValidator(),
            clock: clock,
            journal: [],
            engine: defaultConsentFormAuditEngine(flags)
        )
    }
}
