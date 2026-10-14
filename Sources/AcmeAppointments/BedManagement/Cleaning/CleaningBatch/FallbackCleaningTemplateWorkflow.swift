import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves fallback cleaning templates through their life cycle and keeps a journal of what it did.
    final class FallbackCleaningTemplateWorkflow {
        var store: any FallbackCleaningTemplateStore
        var validator: FallbackCleaningTemplateValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any FallbackCleaningTemplateStore, validator: FallbackCleaningTemplateValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback cleaning template \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FallbackCleaningTemplateStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback cleaning template \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FallbackCleaningTemplateStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
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

    static func newFallbackCleaningTemplateWorkflow(_ store: any FallbackCleaningTemplateStore, clock: any Kit.Clocks.Clock) -> FallbackCleaningTemplateWorkflow {
        return FallbackCleaningTemplateWorkflow(
            store: store,
            validator: defaultFallbackCleaningTemplateValidator(),
            clock: clock,
            journal: []
        )
    }
}
