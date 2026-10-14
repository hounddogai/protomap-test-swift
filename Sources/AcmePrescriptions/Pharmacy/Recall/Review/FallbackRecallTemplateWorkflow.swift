import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves fallback recall templates through their life cycle and keeps a journal of what it did.
    final class FallbackRecallTemplateWorkflow {
        var store: any FallbackRecallTemplateStore
        var validator: FallbackRecallTemplateValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any FallbackRecallTemplateStore, validator: FallbackRecallTemplateValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback recall template \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FallbackRecallTemplateStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback recall template \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FallbackRecallTemplateStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
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

    static func newFallbackRecallTemplateWorkflow(_ store: any FallbackRecallTemplateStore, clock: any Kit.Clocks.Clock) -> FallbackRecallTemplateWorkflow {
        return FallbackRecallTemplateWorkflow(
            store: store,
            validator: defaultFallbackRecallTemplateValidator(),
            clock: clock,
            journal: []
        )
    }
}
