import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves manual recall quotas through their life cycle and keeps a journal of what it did.
    final class ManualRecallQuotaWorkflow {
        var store: any ManualRecallQuotaStore
        var validator: ManualRecallQuotaValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ManualRecallQuotaEngine

        init(store: any ManualRecallQuotaStore, validator: ManualRecallQuotaValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ManualRecallQuotaEngine) {
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
                throw Kit.Failure("manual recall quota \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ManualRecallQuotaStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual recall quota \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ManualRecallQuotaStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual recall quota \(code) not found")
            }
            let result = engine.run(item)
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

    static func newManualRecallQuotaWorkflow(_ store: any ManualRecallQuotaStore, clock: any Kit.Clocks.Clock) -> ManualRecallQuotaWorkflow {
        return ManualRecallQuotaWorkflow(
            store: store,
            validator: defaultManualRecallQuotaValidator(),
            clock: clock,
            journal: [],
            engine: defaultManualRecallQuotaEngine()
        )
    }
}
