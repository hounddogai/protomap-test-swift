import AcmePlatform
import Foundation

extension Labs {
    /// Moves weighted courier drafts through their life cycle and keeps a journal of what it did.
    final class WeightedCourierDraftManager {
        var store: any WeightedCourierDraftStore
        var validator: WeightedCourierDraftValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any WeightedCourierDraftStore, validator: WeightedCourierDraftValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("weighted courier draft \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(WeightedCourierDraftStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted courier draft \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(WeightedCourierDraftStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func audit(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.updatedAt > cutoff {
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

    static func newWeightedCourierDraftManager(_ store: any WeightedCourierDraftStore, clock: any Kit.Clocks.Clock) -> WeightedCourierDraftManager {
        return WeightedCourierDraftManager(
            store: store,
            validator: defaultWeightedCourierDraftValidator(),
            clock: clock,
            journal: []
        )
    }
}
