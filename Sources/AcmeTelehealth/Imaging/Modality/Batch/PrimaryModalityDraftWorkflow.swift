import AcmePlatform
import Foundation

extension Imaging {
    /// Moves primary modality drafts through their life cycle and keeps a journal of what it did.
    final class PrimaryModalityDraftWorkflow {
        var store: any PrimaryModalityDraftStore
        var validator: PrimaryModalityDraftValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PrimaryModalityDraftEngine

        init(store: any PrimaryModalityDraftStore, validator: PrimaryModalityDraftValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PrimaryModalityDraftEngine) {
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
                throw Kit.Failure("primary modality draft \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PrimaryModalityDraftStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary modality draft \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PrimaryModalityDraftStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary modality draft \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newPrimaryModalityDraftWorkflow(_ store: any PrimaryModalityDraftStore, clock: any Kit.Clocks.Clock) -> PrimaryModalityDraftWorkflow {
        return PrimaryModalityDraftWorkflow(
            store: store,
            validator: defaultPrimaryModalityDraftValidator(),
            clock: clock,
            journal: [],
            engine: defaultPrimaryModalityDraftEngine()
        )
    }
}
