import AcmePlatform
import Foundation

extension Imaging {
    /// Moves adaptive priority audits through their life cycle and keeps a journal of what it did.
    final class AdaptivePriorityAuditService {
        var store: any AdaptivePriorityAuditStore
        var validator: AdaptivePriorityAuditValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: AdaptivePriorityAuditEngine

        init(store: any AdaptivePriorityAuditStore, validator: AdaptivePriorityAuditValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: AdaptivePriorityAuditEngine) {
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
                throw Kit.Failure("adaptive priority audit \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AdaptivePriorityAuditStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("adaptive priority audit \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AdaptivePriorityAuditStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("adaptive priority audit \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newAdaptivePriorityAuditService(_ store: any AdaptivePriorityAuditStore, clock: any Kit.Clocks.Clock) -> AdaptivePriorityAuditService {
        return AdaptivePriorityAuditService(
            store: store,
            validator: defaultAdaptivePriorityAuditValidator(),
            clock: clock,
            journal: [],
            engine: defaultAdaptivePriorityAuditEngine()
        )
    }
}
