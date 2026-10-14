import AcmePlatform
import Foundation

extension Referrals {
    /// Moves fallback network checkpoints through their life cycle and keeps a journal of what it did.
    final class FallbackNetworkCheckpointService {
        var store: any FallbackNetworkCheckpointStore
        var validator: FallbackNetworkCheckpointValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any FallbackNetworkCheckpointStore, validator: FallbackNetworkCheckpointValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("fallback network checkpoint \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FallbackNetworkCheckpointStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback network checkpoint \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FallbackNetworkCheckpointStatus.stopped)
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

    static func newFallbackNetworkCheckpointService(_ store: any FallbackNetworkCheckpointStore, clock: any Kit.Clocks.Clock) -> FallbackNetworkCheckpointService {
        return FallbackNetworkCheckpointService(
            store: store,
            validator: defaultFallbackNetworkCheckpointValidator(),
            clock: clock,
            journal: []
        )
    }
}
