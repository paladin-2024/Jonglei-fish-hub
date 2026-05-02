export function Skeleton({ className = '', style = {} }) {
  return (
    <div
      className={`shimmer rounded-lg ${className}`}
      style={style}
      aria-hidden="true"
    />
  )
}

export function StatSkeleton() {
  return (
    <div className="bg-white rounded-xl shadow-card overflow-hidden">
      <div className="h-[3px] shimmer" />
      <div className="p-5 space-y-3">
        <div className="flex justify-between items-start">
          <Skeleton className="h-3 w-24" />
          <Skeleton className="h-8 w-8 rounded-lg" />
        </div>
        <Skeleton className="h-9 w-20" />
        <Skeleton className="h-3 w-32 mt-1" />
      </div>
    </div>
  )
}

export function TableSkeleton({ rows = 5, cols = 5 }) {
  return (
    <div className="p-4 space-y-2.5" aria-hidden="true">
      {Array.from({ length: rows }).map((_, r) => (
        <div key={r} className="flex gap-4 items-center py-1">
          {Array.from({ length: cols }).map((_, c) => (
            <Skeleton
              key={c}
              className="h-4"
              style={{ flex: c === 0 ? '1.4' : '1' }}
            />
          ))}
        </div>
      ))}
    </div>
  )
}

export function CardSkeleton() {
  return (
    <div className="bg-white rounded-xl shadow-card overflow-hidden p-5 space-y-3">
      <Skeleton className="h-4 w-32" />
      <Skeleton className="h-20 w-full" />
      <Skeleton className="h-3 w-48" />
    </div>
  )
}
