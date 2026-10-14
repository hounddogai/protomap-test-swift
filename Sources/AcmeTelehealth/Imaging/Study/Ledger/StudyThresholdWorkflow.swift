import AcmePlatform
import Foundation

extension Imaging {
    /// Moves study thresholds through their life cycle and keeps a journal of what it did.
    final class StudyThresholdCoordinator {
        var store: any StudyThresholdStore
        var validator: StudyThresholdValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any StudyThresholdStore, validator: StudyThresholdValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("study threshold \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(StudyThresholdStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("study threshold \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(StudyThresholdStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
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

    static func newStudyThresholdCoordinator(_ store: any StudyThresholdStore, clock: any Kit.Clocks.Clock) -> StudyThresholdCoordinator {
        return StudyThresholdCoordinator(
            store: store,
            validator: defaultStudyThresholdValidator(),
            clock: clock,
            journal: []
        )
    }
}
