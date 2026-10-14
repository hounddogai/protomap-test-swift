import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves alert checkpoints through their life cycle and keeps a journal of what it did.
    final class AlertCheckpointCoordinator {
        var store: any AlertCheckpointStore
        var validator: AlertCheckpointValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any AlertCheckpointStore, validator: AlertCheckpointValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("alert checkpoint \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AlertCheckpointStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("alert checkpoint \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AlertCheckpointStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newAlertCheckpointCoordinator(_ store: any AlertCheckpointStore, clock: any Kit.Clocks.Clock) -> AlertCheckpointCoordinator {
        return AlertCheckpointCoordinator(
            store: store,
            validator: defaultAlertCheckpointValidator(),
            clock: clock,
            journal: []
        )
    }
}
