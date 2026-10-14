import AcmePlatform
import Foundation

extension Staffing {
    /// Moves pending overtime agreements through their life cycle and keeps a journal of what it did.
    final class PendingOvertimeAgreementCoordinator {
        var store: any PendingOvertimeAgreementStore
        var validator: PendingOvertimeAgreementValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PendingOvertimeAgreementEngine

        init(store: any PendingOvertimeAgreementStore, validator: PendingOvertimeAgreementValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PendingOvertimeAgreementEngine) {
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
                throw Kit.Failure("pending overtime agreement \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PendingOvertimeAgreementStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending overtime agreement \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PendingOvertimeAgreementStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending overtime agreement \(code) not found")
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

    static func newPendingOvertimeAgreementCoordinator(_ store: any PendingOvertimeAgreementStore, clock: any Kit.Clocks.Clock) -> PendingOvertimeAgreementCoordinator {
        return PendingOvertimeAgreementCoordinator(
            store: store,
            validator: defaultPendingOvertimeAgreementValidator(),
            clock: clock,
            journal: [],
            engine: defaultPendingOvertimeAgreementEngine()
        )
    }
}
