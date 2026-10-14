import AcmePlatform
import Foundation

extension Labs {
    /// Moves adaptive result drafts through their life cycle and keeps a journal of what it did.
    final class AdaptiveResultDraftWorkflow {
        var store: any AdaptiveResultDraftStore
        var validator: AdaptiveResultDraftValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any AdaptiveResultDraftStore, validator: AdaptiveResultDraftValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("adaptive result draft \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AdaptiveResultDraftStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("adaptive result draft \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AdaptiveResultDraftStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
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

    static func newAdaptiveResultDraftWorkflow(_ store: any AdaptiveResultDraftStore, clock: any Kit.Clocks.Clock) -> AdaptiveResultDraftWorkflow {
        return AdaptiveResultDraftWorkflow(
            store: store,
            validator: defaultAdaptiveResultDraftValidator(),
            clock: clock,
            journal: []
        )
    }
}
