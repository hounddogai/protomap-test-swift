import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves lenient isolation templates through their life cycle and keeps a journal of what it did.
    final class LenientIsolationTemplateWorkflow {
        var store: any LenientIsolationTemplateStore
        var validator: LenientIsolationTemplateValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any LenientIsolationTemplateStore, validator: LenientIsolationTemplateValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("lenient isolation template \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LenientIsolationTemplateStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient isolation template \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LenientIsolationTemplateStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func reviewStale(_ cutoff: Int) -> Int {
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

    static func newLenientIsolationTemplateWorkflow(_ store: any LenientIsolationTemplateStore, clock: any Kit.Clocks.Clock) -> LenientIsolationTemplateWorkflow {
        return LenientIsolationTemplateWorkflow(
            store: store,
            validator: defaultLenientIsolationTemplateValidator(),
            clock: clock,
            journal: []
        )
    }
}
