import AcmePlatform
import Foundation

extension Imaging {
    /// Moves adaptive priority groups through their life cycle and keeps a journal of what it did.
    final class AdaptivePriorityGroupManager {
        var store: any AdaptivePriorityGroupStore
        var validator: AdaptivePriorityGroupValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any AdaptivePriorityGroupStore, validator: AdaptivePriorityGroupValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("adaptive priority group \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AdaptivePriorityGroupStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("adaptive priority group \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AdaptivePriorityGroupStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
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

    static func newAdaptivePriorityGroupManager(_ store: any AdaptivePriorityGroupStore, clock: any Kit.Clocks.Clock) -> AdaptivePriorityGroupManager {
        return AdaptivePriorityGroupManager(
            store: store,
            validator: defaultAdaptivePriorityGroupValidator(),
            clock: clock,
            journal: []
        )
    }
}
