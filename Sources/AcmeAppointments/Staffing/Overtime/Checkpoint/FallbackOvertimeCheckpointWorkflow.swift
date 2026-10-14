import AcmePlatform
import Foundation

extension Staffing {
    /// Moves fallback overtime checkpoints through their life cycle and keeps a journal of what it did.
    final class FallbackOvertimeCheckpointService {
        var store: any FallbackOvertimeCheckpointStore
        var validator: FallbackOvertimeCheckpointValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any FallbackOvertimeCheckpointStore, validator: FallbackOvertimeCheckpointValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback overtime checkpoint \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FallbackOvertimeCheckpointStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback overtime checkpoint \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FallbackOvertimeCheckpointStatus.stopped)
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

    static func newFallbackOvertimeCheckpointService(_ store: any FallbackOvertimeCheckpointStore, clock: any Kit.Clocks.Clock) -> FallbackOvertimeCheckpointService {
        return FallbackOvertimeCheckpointService(
            store: store,
            validator: defaultFallbackOvertimeCheckpointValidator(),
            clock: clock,
            journal: []
        )
    }
}
