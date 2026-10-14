import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves primary care gap targets through their life cycle and keeps a journal of what it did.
    final class PrimaryCareGapTargetWorkflow {
        var store: any PrimaryCareGapTargetStore
        var validator: PrimaryCareGapTargetValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PrimaryCareGapTargetEngine

        init(store: any PrimaryCareGapTargetStore, validator: PrimaryCareGapTargetValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PrimaryCareGapTargetEngine) {
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
                throw Kit.Failure("primary care gap target \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PrimaryCareGapTargetStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary care gap target \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PrimaryCareGapTargetStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary care gap target \(code) not found")
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
                if item.createdAt > cutoff {
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

    static func newPrimaryCareGapTargetWorkflow(_ store: any PrimaryCareGapTargetStore, clock: any Kit.Clocks.Clock) -> PrimaryCareGapTargetWorkflow {
        return PrimaryCareGapTargetWorkflow(
            store: store,
            validator: defaultPrimaryCareGapTargetValidator(),
            clock: clock,
            journal: [],
            engine: defaultPrimaryCareGapTargetEngine()
        )
    }
}
