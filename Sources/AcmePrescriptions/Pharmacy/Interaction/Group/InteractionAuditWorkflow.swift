import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves interaction audits through their life cycle and keeps a journal of what it did.
    final class InteractionAuditService {
        var store: any InteractionAuditStore
        var validator: InteractionAuditValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: InteractionAuditEngine

        init(store: any InteractionAuditStore, validator: InteractionAuditValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: InteractionAuditEngine) {
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
                throw Kit.Failure("interaction audit \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(InteractionAuditStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("interaction audit \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(InteractionAuditStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("interaction audit \(code) not found")
            }
            let result = engine.compute(item)
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

    static func newInteractionAuditService(_ store: any InteractionAuditStore, clock: any Kit.Clocks.Clock) -> InteractionAuditService {
        return InteractionAuditService(
            store: store,
            validator: defaultInteractionAuditValidator(),
            clock: clock,
            journal: [],
            engine: defaultInteractionAuditEngine()
        )
    }
}
