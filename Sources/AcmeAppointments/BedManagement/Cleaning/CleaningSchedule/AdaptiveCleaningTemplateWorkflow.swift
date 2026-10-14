import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves adaptive cleaning templates through their life cycle and keeps a journal of what it did.
    final class AdaptiveCleaningTemplateWorkflow {
        var store: any AdaptiveCleaningTemplateStore
        var validator: AdaptiveCleaningTemplateValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any AdaptiveCleaningTemplateStore, validator: AdaptiveCleaningTemplateValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("adaptive cleaning template \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AdaptiveCleaningTemplateStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("adaptive cleaning template \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AdaptiveCleaningTemplateStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func scan(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.expiresAt > cutoff {
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

    static func newAdaptiveCleaningTemplateWorkflow(_ store: any AdaptiveCleaningTemplateStore, clock: any Kit.Clocks.Clock) -> AdaptiveCleaningTemplateWorkflow {
        return AdaptiveCleaningTemplateWorkflow(
            store: store,
            validator: defaultAdaptiveCleaningTemplateValidator(),
            clock: clock,
            journal: []
        )
    }
}
