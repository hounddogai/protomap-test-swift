import AcmePlatform
import Foundation

extension Imaging {
    /// Moves rolling priority agreements through their life cycle and keeps a journal of what it did.
    final class RollingPriorityAgreementManager {
        var store: any RollingPriorityAgreementStore
        var validator: RollingPriorityAgreementValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RollingPriorityAgreementEngine

        init(store: any RollingPriorityAgreementStore, validator: RollingPriorityAgreementValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RollingPriorityAgreementEngine) {
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
                throw Kit.Failure("rolling priority agreement \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RollingPriorityAgreementStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling priority agreement \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RollingPriorityAgreementStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling priority agreement \(code) not found")
            }
            let result = engine.price(item)
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

    static func newRollingPriorityAgreementManager(_ store: any RollingPriorityAgreementStore, clock: any Kit.Clocks.Clock) -> RollingPriorityAgreementManager {
        return RollingPriorityAgreementManager(
            store: store,
            validator: defaultRollingPriorityAgreementValidator(),
            clock: clock,
            journal: [],
            engine: defaultRollingPriorityAgreementEngine()
        )
    }
}
