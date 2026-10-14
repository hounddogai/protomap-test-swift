import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves outreach checkpoints through their life cycle and keeps a journal of what it did.
    final class OutreachCheckpointService {
        var store: any OutreachCheckpointStore
        var validator: OutreachCheckpointValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any OutreachCheckpointStore, validator: OutreachCheckpointValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("outreach checkpoint \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(OutreachCheckpointStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("outreach checkpoint \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(OutreachCheckpointStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func sweep(_ cutoff: Int) -> Int {
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

    static func newOutreachCheckpointService(_ store: any OutreachCheckpointStore, clock: any Kit.Clocks.Clock) -> OutreachCheckpointService {
        return OutreachCheckpointService(
            store: store,
            validator: defaultOutreachCheckpointValidator(),
            clock: clock,
            journal: []
        )
    }
}
