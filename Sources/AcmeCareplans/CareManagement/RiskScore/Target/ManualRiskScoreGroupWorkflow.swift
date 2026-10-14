import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves manual risk score groups through their life cycle and keeps a journal of what it did.
    final class ManualRiskScoreGroupManager {
        var store: any ManualRiskScoreGroupStore
        var validator: ManualRiskScoreGroupValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ManualRiskScoreGroupEngine

        init(store: any ManualRiskScoreGroupStore, validator: ManualRiskScoreGroupValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ManualRiskScoreGroupEngine) {
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
                throw Kit.Failure("manual risk score group \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ManualRiskScoreGroupStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual risk score group \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ManualRiskScoreGroupStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual risk score group \(code) not found")
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

    static func newManualRiskScoreGroupManager(_ store: any ManualRiskScoreGroupStore, clock: any Kit.Clocks.Clock) -> ManualRiskScoreGroupManager {
        return ManualRiskScoreGroupManager(
            store: store,
            validator: defaultManualRiskScoreGroupValidator(),
            clock: clock,
            journal: [],
            engine: defaultManualRiskScoreGroupEngine()
        )
    }
}
