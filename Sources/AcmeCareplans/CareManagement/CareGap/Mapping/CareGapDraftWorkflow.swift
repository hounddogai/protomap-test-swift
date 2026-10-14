import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves care gap drafts through their life cycle and keeps a journal of what it did.
    final class CareGapDraftCoordinator {
        var store: any CareGapDraftStore
        var validator: CareGapDraftValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any CareGapDraftStore, validator: CareGapDraftValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("care gap draft \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CareGapDraftStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("care gap draft \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CareGapDraftStatus.retired)
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

    static func newCareGapDraftCoordinator(_ store: any CareGapDraftStore, clock: any Kit.Clocks.Clock) -> CareGapDraftCoordinator {
        return CareGapDraftCoordinator(
            store: store,
            validator: defaultCareGapDraftValidator(),
            clock: clock,
            journal: []
        )
    }
}
